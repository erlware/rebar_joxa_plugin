%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
%% -------------------------------------------------------------------
%%
%% Plugin to build joxa source files
%%
%% Copyright (c) 2009 Eric Merritt (ericbmerritt@gmail.com)
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.
%% -------------------------------------------------------------------
-module(rebar_joxa_plugin).

-export([compile/2,
         pre_eunit/2]).

-include_lib("rebar/include/rebar.hrl").

%% ===================================================================
%% Public API
%% ===================================================================
-spec compile(rebar_config:config(), file:filename()) -> term().
compile(Config, _AppFile) ->
    build_jxa(Config, "src", "ebin").

-spec pre_eunit(rebar_config:config(), file:filename()) -> ok.
pre_eunit(Config, _AppFIle) ->
    build_jxa(Config, "test", ".eunit").

-spec build_jxa(rebar_config:config(), file:filename(), file:filename()) -> term().
build_jxa(Config, Src, OutDir) ->
    %% Convert simple extension to proper regex
    Files = rebar_utils:find_files(Src, ".*\\.jxa$"),

check_existing(_Config, _Outdir, []) ->
    %% No files to compile, all is good
    ok;
check_existing(Config, OutDir, Files) ->
    case code:which('joxa-compiler') of
        non_existing ->
            ?ERROR("~n"
                   "missing joxa compiler ~n"
                   "  You must do one of the following:~n"
                   "    a) Install JOXA globally in your erl libs~n"
                   "    b) Add JOXA as a dep for your project, eg:~n"
                   "       {joxa, \"0.1.0\",~n"
                   "        {git, \"git://github.com/erlware/joxa\",~n"
                   "         {tag, \"v0.1.0\"}}}~n"
                   "~n", []),
            rebar_utils:abort("*** MISSING JOXA COMPILER ***~n", []);
        _ ->
            do_build(Config, Outdir, Files)
    end.

do_build(Config, Outdir, Files) ->
    Opts0 = rebar_config:get_list(Config, joxa_opts, []),
    Opts1 =
        case proplists:is_defined(outdir, Opts0) of
            true ->
                Opts0;
            false ->
                [{outdir, OutDir} | Opts0]
        end,
    case 'joxa-concurrent-compiler':'do-compile'(Files, Opts1) of
        {error, _} ->
            ?ABORT("build failure", []);
        ok ->
            ok
    end.
