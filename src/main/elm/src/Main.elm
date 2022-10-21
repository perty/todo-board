module Main exposing (main)

import Browser
import Browser.Events
import Dict exposing (Dict)
import Html exposing (div, p, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (on, onMouseEnter)
import Json.Decode as Decode


type Msg
    = DragStart NodeId Position
    | DragMove NodeId Bool Position
    | DragStop NodeId
    | ColumnEntered Column
    | ClickedCard


type alias Model =
    { dragState : DragState
    , inColumn : Maybe Column
    , startPos : Position
    , cards : Cards
    }


type alias Cards =
    Dict NodeId TodoCard


type alias Position =
    { x : Float
    , y : Float
    }


type DragState
    = Static
    | Moving NodeId


type alias TodoCard =
    { column : Column
    , id : NodeId
    , position : Position
    }


type alias Column =
    String


type alias NodeId =
    Int


allColumns : List Column
allColumns =
    [ "todo", "doing", "done" ]


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )


initialModel : Model
initialModel =
    { inColumn = Nothing
    , dragState = Static
    , startPos = Position 0 0
    , cards = initialCards
    }


initialCards : Cards
initialCards =
    Dict.fromList
        [ ( 1
          , { id = 1
            , column = "todo"
            , position = Position 0 0
            }
          )
        , ( 2
          , { id = 2
            , column = "todo"
            , position = Position 0 0
            }
          )
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DragStart nodeId startPos ->
            ( { model
                | dragState = Moving nodeId
                , startPos = startPos
                , cards = setPosition model.cards nodeId startPos
              }
            , Cmd.none
            )

        ClickedCard ->
            ( model, Cmd.none )

        DragMove nodeId isDown position ->
            ( { model
                | dragState =
                    if isDown then
                        Moving nodeId

                    else
                        Static
                , cards = setPosition model.cards nodeId position
              }
            , Cmd.none
            )

        DragStop nodeId ->
            let
                newCards =
                    case model.inColumn of
                        Just column ->
                            setColumn model.cards nodeId column

                        Nothing ->
                            model.cards
            in
            ( { model
                | cards = newCards
                , dragState = Static
                , inColumn = Nothing
              }
            , Cmd.none
            )

        ColumnEntered column ->
            ( { model | inColumn = Just column }, Cmd.none )


setColumn : Cards -> NodeId -> Column -> Cards
setColumn cards nodeId column =
    case findCard nodeId cards of
        Just card ->
            insertCard nodeId { card | column = column } cards

        Nothing ->
            cards


setPosition : Cards -> NodeId -> Position -> Cards
setPosition cards nodeId position =
    case findCard nodeId cards of
        Just card ->
            insertCard nodeId { card | position = position } cards

        Nothing ->
            cards


findCard : NodeId -> Cards -> Maybe TodoCard
findCard nodeId cards =
    Dict.get nodeId cards


insertCard : NodeId -> TodoCard -> Cards -> Cards
insertCard nodeId card cards =
    Dict.insert nodeId card cards



-- View


view : Model -> Html.Html Msg
view model =
    div []
        [ div [ class "header" ]
            [ p [] [ text "Something" ]
            ]
        , div [ class "column-container" ]
            [ div [ class "column-head" ]
                [ text "Todo"
                ]
            , div
                [ class "column-head" ]
                [ text "Doing"
                ]
            , div
                [ class "column-head" ]
                [ text "Done"
                ]
            ]
        , div [ class "card-container" ]
            (List.map (viewCardsOfColumn model) allColumns)
        ]


viewCardsOfColumn : Model -> Column -> Html.Html Msg
viewCardsOfColumn model column =
    let
        cardsOfColumn =
            Dict.values model.cards |> List.filter (\card -> card.column == column)

        classes =
            "card-column"
                ++ (if model.inColumn == Just column && model.dragState /= Static then
                        " in-column"

                    else
                        ""
                   )
    in
    div [ class classes, onMouseEnter (ColumnEntered column) ]
        (List.map (viewTodoCard model.dragState) cardsOfColumn)


viewTodoCard : DragState -> TodoCard -> Html.Html Msg
viewTodoCard dragState card =
    let
        classes =
            "card"
                ++ (if dragState == Moving card.id then
                        " card-dragged"

                    else
                        ""
                   )

        dragging =
            case dragState of
                Static ->
                    False

                Moving nodeId ->
                    nodeId == card.id
    in
    if dragging then
        div []
            [ div
                [ class classes
                , style "left" (String.fromFloat card.position.x ++ "px")
                , style "top" (String.fromFloat card.position.y ++ "px")
                ]
                [ p [] [ text <| String.fromInt card.id ]
                ]
            , div [ class "card shadow-card" ]
                []
            ]

    else
        div
            [ class classes
            , on "mousedown" (Decode.map (DragStart card.id) decodeClientPosition)
            ]
            [ p [] [ text <| String.fromInt card.id ]
            ]



-- Subscription


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.dragState of
        Static ->
            Sub.none

        Moving id ->
            Sub.batch
                [ Browser.Events.onMouseUp (Decode.succeed (DragStop id))
                , Browser.Events.onMouseMove (Decode.map2 (DragMove id) decodeButtons decodePosition)
                ]


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


decodeClientPosition : Decode.Decoder Position
decodeClientPosition =
    Decode.map2 Position decodeClientX decodeClientY


decodeClientX : Decode.Decoder Float
decodeClientX =
    Decode.field "clientX" Decode.float


decodeClientY : Decode.Decoder Float
decodeClientY =
    Decode.field "clientY" Decode.float


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
