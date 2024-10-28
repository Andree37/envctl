defmodule Envctl.SessionManager do
  @config_path Path.expand("~/.envctl/config.json")
  @session_store %{}  # In-memory session tracking

  def start_session(project_name) do
    with {:ok, config} <- load_config(),
         {:ok, project} <- Map.fetch(config["projects"], project_name),
         path <- project["path"],
         env_vars <- project["env_vars"] do

      if File.exists?(path) do
        spawn(fn -> setup_session(project_name, env_vars) end)
        IO.puts("Started session for #{project_name} in #{path}")
      else
        IO.puts("Invalid path for project #{project_name}")
      end
    else
      _ -> IO.puts("Project #{project_name} not found in config.")
    end
  end

  defp setup_session(project_name, env_vars) do
    Enum.each(env_vars, fn {key, value} -> System.put_env(key, value) end)
    IO.puts("Environment variables set for #{project_name} session.")
    receive do
      :stop -> clear_env_vars(env_vars)
    end
  end

  def stop_session(project_name) do
    send(find_pid_for(project_name), :stop)
    IO.puts("Stopped session for #{project_name}")
  end

  def list_projects do
    case load_config() do
      {:ok, config} ->
        config["projects"]
        |> Map.keys()
        |> Enum.each(&IO.puts(&1))

      {:error, _} -> IO.puts("Could not load configuration.")
    end
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
end
