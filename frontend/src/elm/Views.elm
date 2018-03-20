module Views exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Models exposing (Model)
import Msgs exposing (..)


rootView : Model -> Html Msg
rootView model =
  div [ class "app" ]
      [ h1 [ class "elmlandr-title" ] [ text model.title ]
      , input [ class "elmlandr-input"
              , onInput ChangeTitle
              , placeholder "Change title here..."
              ] []
      ]
