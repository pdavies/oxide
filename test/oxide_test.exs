defmodule OxideTest do
  use ExUnit.Case
  doctest Oxide

  test "greets the world" do
    assert Oxide.hello() == :world
  end
end
