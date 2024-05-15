defmodule OxideTest do
  import Oxide.Result
  alias Oxide.Result
  use ExUnit.Case
  doctest Oxide.Result

  import Oxide.Result.Dangerous
  doctest Oxide.Result.Dangerous
end
