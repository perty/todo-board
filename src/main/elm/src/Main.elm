module Main exposing (main)

import Browser
import Browser.Events
import Dict exposing (Dict)
import Html exposing (div, p, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onMouseDown, onMouseUp)
import Json.Decode as Decode


type Msg
    = DragStart NodeId
    | DragMove NodeId Bool Position
    | DragStop NodeId
    | ClickedCard


type alias Model =
    { scale : Float
    , graphElementPosition : Position
    , dragState : DragState
    , cards : Dict String (Dict NodeId TodoCard)
    }


type alias Position =
    { x : Float
    , y : Float
    }


type DragState
    = Static
    | Moving NodeId


type alias TodoCard =
    { position : Position
    }


type alias NodeId =
    Int


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )


initialModel : Model
initialModel =
    { scale = 1.0
    , graphElementPosition = Position 0 0
    , dragState = Static
    , cards = initialCards
    }


initialCards : Dict String (Dict NodeId TodoCard)
initialCards =
    Dict.fromList
        [ ( "todo"
          , Dict.fromList
                [ ( 1
                  , { position = Position 125 50
                    }
                  )
                , ( 2
                  , { position = Position 100 100
                    }
                  )
                ]
          )
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DragStart nodeId ->
            ( { model | dragState = Moving nodeId }
            , Cmd.none
            )

        ClickedCard ->
            ( model, Cmd.none )

        DragMove nodeId isDown pos ->
            ( { model
                | dragState =
                    if isDown then
                        Moving nodeId

                    else
                        Static
              }
            , Cmd.none
            )

        DragStop nodeId ->
            ( { model | dragState = Static }, Cmd.none )



-- View


view : Model -> Html.Html Msg
view model =
    div []
        [ div [ class "card-column" ] (drawCardsOfColumn "todo" model.cards)
        , div [ class "card-column" ] (drawCardsOfColumn "doing" model.cards)
        , div [ class "card-column" ] (drawCardsOfColumn "done" model.cards)
        ]


drawCardsOfColumn : String -> Dict String (Dict NodeId TodoCard) -> List (Html.Html Msg)
drawCardsOfColumn column columns =
    case Dict.get column columns of
        Just cards ->
            Dict.keys cards |> List.map drawTodoCard

        Nothing ->
            [ div [] [] ]


drawTodoCard : NodeId -> Html.Html Msg
drawTodoCard nodeId =
    div [ class "card", onMouseDown (DragStart nodeId), onMouseUp (DragStop nodeId) ]
        [ p [] [ text <| String.fromInt nodeId ]
        ]



-- Subscription


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.dragState of
        Static ->
            Sub.none

        Moving id ->
            Browser.Events.onMouseMove (Decode.map2 (DragMove id) decodeButtons decodePosition)


decodePosition : Decode.Decoder Position
decodePosition =
    Decode.map2 Position decodeFractionX decodeFractionY


decodeFractionX : Decode.Decoder Float
decodeFractionX =
    Decode.field "pageX" Decode.float


decodeFractionY : Decode.Decoder Float
decodeFractionY =
    Decode.field "pageY" Decode.float


decodeButtons : Decode.Decoder Bool
decodeButtons =
    Decode.field "buttons" (Decode.map (\buttons -> buttons == 1) Decode.int)


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
