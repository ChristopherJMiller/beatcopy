defmodule Beatcopy do
  @moduledoc """
  Documentation for `Beatcopy`.
  """

  @doc """
  Runs the program

  """
  def main(args) do
    [watchPath, destPath] = args
    expandedPath = Path.expand(watchPath)
    File.cd!(expandedPath)
    IO.puts(["Watching files at ", watchPath])
    schedule_next_tick()
    %{ expandedPath: expandedPath, destPath: destPath }
    |> loop
  end

  defp file_install(file, dest, ".zip") do
    ext = to_char_list(Path.join([dest, Path.rootname(file)]))
    case File.mkdir(ext) do
      :ok ->
        case :zip.unzip(to_char_list(file), [{:cwd, ext}]) do
          {:ok, _ } ->
            IO.puts([file, " installed"])
          {:error, x } -> IO.puts(x)
        end

      {:error, :eexist} -> IO.puts([file, " installation failed, directory exists"])
      {:error, :enospc} -> IO.puts([file, " installation failed, out of space"])
      {:error, :eacces} -> IO.puts([file, " installation failed, permission denied"])
      {:error, _} -> IO.puts([file, " installation failed, not a directory"])
    end
    File.rm!(file)
  end

  defp file_install(file, _, _) do
    IO.puts([file, " not a zip, skipping"])
  end

  defp attempt_file_install([], _) do
    :done
  end

  defp attempt_file_install(list, dest) do
    [file | tail] = list
    file_install(file, dest, Path.extname(file))
    attempt_file_install(tail, dest)
  end

  defp modifyBaseFiles(base_list, []) do
    base_list
  end

  defp modifyBaseFiles(base_list, removed_files) do
    base_list
      |> Map.new(fn x -> { x, x } end)
      |> Map.drop(removed_files)
      |> Map.values
  end

  defp checkBaseFiles(state, list) when map_size(state) == 2 do
    atomed_list = list
            |> Enum.map(fn x -> String.to_atom(x) end)
    %{ baseList: atomed_list, diffList: [] }
      |> Map.merge(state)
  end

  defp checkBaseFiles(state, list) do
    atomed_list = list
                      |> Enum.map(fn x -> String.to_atom(x) end)
    removed_files = state[:baseList]
                    |> Map.new(fn x -> { x, x } end)
                    |> Map.drop(atomed_list)
                    |> Map.values

    new_base = modifyBaseFiles(state[:baseList], removed_files)
    Map.replace!(state, :baseList, new_base)
  end

  defp determineNewFiles(state, list) do
    diff_list = list
                  |> Map.new(fn x -> { String.to_atom(x), String.to_atom(x) }  end)
                  |> Map.drop(state[:baseList])

    new_files = Map.drop(diff_list, state[:diffList])
    new_files
      |> Map.values
      |> Enum.map(fn x -> Atom.to_string(x) end)
      |> attempt_file_install(state[:destPath])

    diff_values = Map.values(diff_list)
    Map.replace!(state, :diffList, diff_values)
  end

  defp loop(state) do
    receive do
      :tick ->
        list = File.ls!(state[:expandedPath])
        schedule_next_tick()
        state
        |> checkBaseFiles(list)
        |> determineNewFiles(list)
        |> loop
    end
  end

  defp schedule_next_tick do
    Process.send_after(self(), :tick, 300)
  end
end
