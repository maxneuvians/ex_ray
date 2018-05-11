defmodule ExRay.SpanTest do
  use ExUnit.Case
  doctest ExRay

  use ExRay, pre: :f1, post: :f2

  alias ExRay.{Store, Span}

  setup_all do
    Store.create
    :ok
  end

  setup do
    span = {
      :span,
      1509045368683303,
      12387109925362352574,
      :root,
      15549390946617352406,
      1526060847,
      [],
      [],
      :undefined
    }
    %{span: span}
  end

  def f1(ctx) do
    assert ctx.meta[:kind] == :test
    :f1 |> Span.open("fred")
  end

  def f2(_ctx, span, _res) do
    span |> Span.close("fred")
  end

  @trace kind: :test
  def test1(a, b) do
    a + b
  end

  test "basic" do
    assert test1(1, 2) == 3
  end

  test "child span", ctx do
    Store.push("fred", ctx[:span])
    assert test1(1, 2) == 3
  end

  test "open/2" do
    span = Span.open("fred", "2")
    assert length(Store.get("2")) == 1
    span |> Span.close("2")
  end

  test "open/3 with trace ID", ctx do
    trace_id = Span.trace_id(ctx[:span])
    span = Span.open("fred", "1", trace_id)
    assert Store.current("1") == span
    assert Span.trace_id(span) == trace_id
    span |> Span.close("1")
  end

  test "open/3", ctx do
    span = Span.open("fred", "1", ctx[:span])
    assert Store.current("1") == span
    span |> Span.close("1")
  end

  test "open/4 with trace ID and parent ID", ctx do
    trace_id = Span.trace_id(ctx[:span])
    parent_id = Span.parent_id(ctx[:span])
    span = Span.open("fred", "1", trace_id, parent_id)
    assert Store.current("1") == span
    assert Span.trace_id(span) == trace_id
    assert Span.parent_id(span) == parent_id
    span |> Span.close("1")
  end

  test "id/1", ctx do
    assert ctx[:span] |> Span.id == 15549390946617352406
  end

  test "ids/1", ctx do
    assert ctx[:span] |> Span.ids == {15549390946617352406, 12387109925362352574, 1526060847}
  end

  test "log/2", %{span: span} do
    log = "Has left the building"
    span = Span.log(span, log)
    logs = elem(span, 7)
    {_ts, capturedLog} = hd(logs)
    assert log == capturedLog
  end 

  test "tag/3", %{span: span} do
    key = :kind
    value = :critical
    span = Span.tag(span, key, value)
    tags = elem(span, 6)
    assert Keyword.has_key?(tags, key) 
    assert tags[key] == value
  end 

  test "parent_id/1", ctx do
    assert ctx[:span] |> Span.parent_id == 1526060847
  end

  test "trace_id/1", ctx do
    assert ctx[:span] |> Span.trace_id == 12387109925362352574
  end
end
