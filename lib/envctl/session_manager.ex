defmodule Envctl.SessionManager do
  @config_path Path.expand("~/.envctl/config.json")
  @session_store %{}

  def start_session(project_name) do
    current_path = File.cwd!()

    with {:ok, config} <- load_config(),
         {:ok, project} <- Map.fetch(config["projects"], project_name),
         path when not is_nil(path) <- project["path"],
         env_vars <- project["env_vars"] do
      if path == current_path do
        Enum.each(env_vars, fn {key, value} ->
          IO.puts("export #{key}=#{value}")
        end)
      else
        IO.puts(
          "The configured path for project #{project_name} does not match the current directory."
        )
      end
    else
      nil -> IO.puts("Path not set for project #{project_name} in config.")
      _ -> IO.puts("Project #{project_name} not found in config.")
    end
  end

  def stop_session(project_name) do
    send(find_pid_for(project_name), :stop)
    IO.puts("Stopped session for #{project_name}")
  end

  def show_env_vars(project_name) do
    current_path = File.cwd!()

    with {:ok, config} <- load_config(),
         {:ok, project} <- Map.fetch(config["projects"], project_name),
         path when path == current_path <- project["path"],
         env_vars <- Map.get(project, "env_vars") do
      if env_vars do
        IO.puts("Environment variables for #{project_name} in #{current_path}:")
        Enum.each(env_vars, fn {key, value} -> IO.puts("#{key}=#{value}") end)
      else
        IO.puts("No environment variables set for #{project_name}")
      end
    else
      _ -> IO.puts("No matching path for #{project_name} in the current directory.")
    end
  end

  def list_projects do
    case load_config() do
      {:ok, config} ->
        config["projects"]
        |> Map.keys()
        |> Enum.each(&IO.puts(&1))

      {:error, :enoent} ->
        create_default_config()
        IO.puts("Configuration file created at #{@config_path}.")
        IO.puts("No projects are currently configured.")

      {:error, _other} ->
        IO.puts("Could not load configuration.")
    end
  end

  def add_env_var(project_name, env_var) do
    with {:ok, config} <- load_config(),
         {:ok, {key, value}} <- parse_env_var(env_var) do
      project = Map.get(config["projects"], project_name, %{})
      path = Map.get(project, "path", File.cwd!())

      updated_project =
        project
        |> Map.put("path", path)
        |> Map.update("env_vars", %{key => value}, &Map.put(&1, key, value))

      updated_config = put_in(config["projects"][project_name], updated_project)

      save_config(updated_config)

      IO.puts(
        "Environment variable #{key}=#{value} added to #{project_name} with path set to #{path}"
      )
    else
      {:error, :invalid_format} -> IO.puts("Invalid format. Use key=value.")
      {:error, _} -> IO.puts("Could not load configuration.")
    end
  end

  defp setup_session(project_name, env_vars) do
    Enum.each(env_vars, fn {key, value} -> System.put_env(key, value) end)
    IO.puts("Environment variables set for #{project_name} session.")

    receive do
      :stop -> clear_env_vars(env_vars)
    end
  end

  defp create_default_config do
    config_dir = Path.dirname(@config_path)

    :ok = File.mkdir_p(config_dir)

    default_content = %{"projects" => %{}} |> Jason.encode!(pretty: true)
    File.write!(@config_path, default_content)
  end

  defp load_config do
    case File.read(@config_path) do
      {:ok, contents} -> Jason.decode(contents)
      {:error, reason} -> {:error, reason}
    end
  end

  defp clear_env_vars(env_vars) do
    Enum.each(env_vars, fn {key, _} -> System.delete_env(key) end)
    IO.puts("Environment variables cleared.")
  end

  defp find_pid_for(project_name) do
    # Implement session lookup based on project_name
  end

  defp parse_env_var(env_var) do
    case String.split(env_var, "=", parts: 2) do
      [key, value] -> {:ok, {key, value}}
      _ -> {:error, :invalid_format}
    end
  end

  defp save_config(config) do
    config_dir = Path.dirname(@config_path)

    IO.puts("Config path: #{@config_path}")
    IO.puts("Directory exists? #{File.exists?(config_dir)}")
    IO.puts("File exists? #{File.exists?(@config_path)}")

    :ok = File.mkdir_p(config_dir)

    encoded_content = Jason.encode!(config, pretty: true)
    File.write!(@config_path, encoded_content)
  end
end
