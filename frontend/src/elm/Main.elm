module Main exposing (main)

import Html exposing (..)

import Models exposing (Model, defaultModel)
import Msgs exposing (..)
import Updates exposing (updateWithMiddleware)
import Views exposing (rootView)
import Subscriptions exposing (subscriptions)


init : Maybe Model -> ( Model, Cmd Msg )
init savedModel =
  Maybe.withDefault defaultModel savedModel ! []


main =
  Html.programWithFlags
    { init = init
    , update = updateWithMiddleware
    , view = rootView
    , subscriptions = subscriptions
    }
