module Updates exposing (..)

import Models exposing (Model)
import Msgs exposing (..)
import Ports exposing (setStorage)


-- the base update function
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      model ! []

    ChangeTitle newTitle ->
      { model | title = newTitle } ! []


-- storage middlewares have this type signature
persistModel : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
persistModel ( model, cmds ) =
  model ! [ setStorage model, cmds ]


-- and can be added to the forward pipe chain here
updateWithMiddleware : Msg -> Model -> ( Model, Cmd Msg )
updateWithMiddleware msg model =
  update msg model
    |> persistModel
