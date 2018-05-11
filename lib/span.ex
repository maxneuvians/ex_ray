defmodule ExRay.Span do
  @moduledoc """
  A set of convenience functions to manage spans.
  """

  @doc """
  Create a new root span with a given name and unique request chain ID.
  The request ID uniquely identifies the call chain and will be used as
  the primary key in the ETS table tracking the span chain.
  """
  @spec open(String.t, String.t) :: any
  def open(name, req_id) do
    span = req_id
    |> ExRay.Store.current
    |> case do
      nil    -> name |> :otter.start
      p_span -> name |> :otter.start(p_span)
    end

    req_id |> ExRay.Store.push(span)
  end

  @doc """
  Creates a new span with a given trace ID 
  """
  @spec open(String.t, String.t, integer) :: any
  def open(name, req_id, trace_id) when is_integer(trace_id) do
    span = name |> :otter.start(trace_id)

    req_id |> ExRay.Store.push(span)
  end

  @doc """
  Creates a new span with a given parent span
  """
  @spec open(String.t, String.t, any) :: any
  def open(name, req_id, p_span) do
    span = name |> :otter.start(p_span)

    req_id |> ExRay.Store.push(span)
  end

  @doc """
  Creates a new span with a given trace ID and parent ID 
  """
  @spec open(String.t, String.t, integer, integer) :: any
  def open(name, req_id, trace_id, parent_id) do
    span = name |> :otter.start(trace_id, parent_id)

    req_id |> ExRay.Store.push(span)
  end

  @doc """
  Closes the given span and pops the span state in the associated ETS
  span chain.
  """
  @spec close(any, String.t) :: any
  def close(span, req_id) do
    span |> :otter.finish()
    ExRay.Store.pop(req_id)
  end
  
  @doc """
  Convenience to retrive the span ID from a given span
  """
  @spec id({:span, integer, integer, String.t, integer, integer, list(), list(), integer}) :: Integer
  def id({:span, _, _, _, id, _, _, _, _}) do
    id
  end

  @doc """
  Convenience to retrive the span ID, trace_ID, and parent ID from a given span
  """
  @spec ids({:span, integer, integer, String.t, integer, integer, list(), list(), integer}) :: {Integer, Integer, Integer}
  def ids({:span, _, trace_id, _, id, parent_id, _, _, _}) do
    {id, trace_id, parent_id}
  end

  @doc """
  Adds a log to a span
  """
  @spec log(any, any) :: any
  def log(span, text) do
    span |> :otter.log(text)
  end

  @doc """
  Convenience to retrive the parent ID from a given span
  """
  @spec parent_id({:span, integer, integer, String.t, integer, integer, list(), list(), integer}) :: Integer
  def parent_id({:span, _, _, _, _, parent_id, _, _, _}) do
    parent_id
  end

  @doc """
  Adds a tag to a span
  """
  @spec tag(any, any, any) :: any
  def tag(span, key, value) do
    span |> :otter.tag(key, value)
  end

  @doc """
  Convenience to retrive the trace ID from a given span
  """
  @spec trace_id({:span, integer, integer, String.t, integer, integer, list(), list(), integer}) :: String.t
  def trace_id({:span, _, trace_id, _, _, _, _, _, _}) do
    trace_id
  end
end
