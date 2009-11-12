%% @author Marc Worrell <marc@worrell.nl>
%% @copyright 2009 Marc Worrell
%% @date 2009-07-18
%% @doc Adds support to the admin for easier editing of events.

%% Copyright 2009 Marc Worrell
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%% 
%%     http://www.apache.org/licenses/LICENSE-2.0
%% 
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(mod_admin_event).
-author("Marc Worrell <marc@worrell.nl>").
-behaviour(gen_server).

-mod_title("Admin event support").
-mod_description("Easier creation and editing of events.").
-mod_prio(500).

%% gen_server exports
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/1]).

%% interface functions
-export([
    observe/2
]).

-include_lib("zotonic.hrl").

-record(state, {context}).


observe({search_query, Req, OffsetLimit}, Context) ->
    search(Req, OffsetLimit, Context).

    %% @doc Return the list of events for a performer, ordered on start date
    %% @spec search(SearchSpec, Range, Context) -> #search_sql{}
    search({event_for_performer, [{id, Id}]}, _OffsetLimit, Context) ->
        PredPerfomerId = m_predicate:name_to_id_check(performer, Context),
        #search_sql{
            select="r.id",
            from="rsc r, edge e",
            where="r.id = e.subject_id and e.predicate_id = $1 and e.object_id = $2",
            order="r.pivot_date_start asc",
            tables=[{rsc,"r"}],
            args=[PredPerfomerId, Id],
            cats=[{"r", event}]
        };
    search(_, _, _) ->
        undefined.

%%====================================================================
%% API
%%====================================================================
%% @spec start_link(Args) -> {ok,Pid} | ignore | {error,Error}
%% @doc Starts the server
start_link(Args) when is_list(Args) ->
    gen_server:start_link(?MODULE, Args, []).

%%====================================================================
%% gen_server callbacks
%%====================================================================

%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore               |
%%                     {stop, Reason}
%% @doc Initiates the server.
init(Args) ->
    process_flag(trap_exit, true),
    {context, Context} = proplists:lookup(context, Args),
    z_notifier:observe(search_query, {?MODULE, observe}, Context),
    {ok, #state{context=z_context:new(Context)}}.

%% @spec handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%% @doc Trap unknown calls
handle_call(Message, _From, State) ->
    {stop, {unknown_call, Message}, State}.


%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @doc Trap unknown casts
handle_cast(Message, State) ->
    {stop, {unknown_cast, Message}, State}.



%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% @doc Handling all non call/cast messages
handle_info(_Info, State) ->
    {noreply, State}.

%% @spec terminate(Reason, State) -> void()
%% @doc This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
terminate(_Reason, State) ->
    z_notifier:detach(search_query, {?MODULE, observe}, State#state.context),
    ok.

%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @doc Convert process state when code is changed

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%%====================================================================
%% support functions
%%====================================================================

