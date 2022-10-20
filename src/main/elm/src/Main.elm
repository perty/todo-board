module Main exposing (main)

import Browser
import Html exposing (div, text)


type alias Model =
    String


type Msg
    = NoOp


init : () -> ( Model, Cmd Msg )
init _ =
    ( "Hello", Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    div []
        [ text model
        ]


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
