defmodule Envctl.CLI do
  def main(args) do
    case args do
      ["start", project_name] -> Envctl.SessionManager.start_session(project_name)
      ["stop", project_name] -> Envctl.SessionManager.stop_session(project_name)
      ["list"] -> Envctl.SessionManager.list_projects()
      ["add", project_name, env_var] -> Envctl.SessionManager.add_env_var(project_name, env_var)
      ["show", project_name] -> Envctl.SessionManager.show_env_vars(project_name)
      _ -> IO.puts("Usage: envctl [start|stop|list] <project_name>")
    end
  end
end
