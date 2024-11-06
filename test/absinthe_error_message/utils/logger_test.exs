defmodule AbsintheErrorMessage.Utils.LoggerTest do
  use ExUnit.Case
  doctest AbsintheErrorMessage.Utils.Logger

  import ExUnit.CaptureLog

  @logger_prefix "AbsintheErrorMessage.Utils.LoggerTest"

  test "debug" do
    assert capture_log([level: :debug], fn ->
      AbsintheErrorMessage.Utils.Logger.debug(@logger_prefix, "debug")
    end) =~ "[AbsintheErrorMessage.Utils.LoggerTest] debug"
  end

  test "info" do
    assert capture_log([level: :info], fn ->
      AbsintheErrorMessage.Utils.Logger.info(@logger_prefix, "info")
    end) =~ "[AbsintheErrorMessage.Utils.LoggerTest] info"
  end

  test "warning" do
    assert capture_log([level: :warning], fn ->
      AbsintheErrorMessage.Utils.Logger.warning(@logger_prefix, "warning")
    end) =~ "[AbsintheErrorMessage.Utils.LoggerTest] warning"
  end

  test "error" do
    assert capture_log([level: :error], fn ->
      AbsintheErrorMessage.Utils.Logger.error(@logger_prefix, "error")
    end) =~ "[AbsintheErrorMessage.Utils.LoggerTest] error"
  end
end
