module Main exposing (main)

import Browser
import Browser.Events
import Dict exposing (Dict, insert)
import Html exposing (div, p, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (on, onMouseEnter)
import Json.Decode as Decode


type Msg
    = DragStart CardId Position
    | DragMove CardId Bool Position
    | DragStop CardId
    | ColumnEntered Column
    | CardEntered CardId
    | ClickedCard


type alias Model =
    { dragState : DragState
    , inColumn : Maybe Column
    , aboveCard : Maybe CardId
    , startPos : Position
    , cards : Cards
    }


type alias Cards =
    Dict CardId TodoCard


type alias Position =
    { x : Float
    , y : Float
    }


type DragState
    = Static
    | Moving CardId Position


type alias TodoCard =
    { column : Column
    , id : CardId
    , order : Int
    }


type alias Column =
    String


type alias CardId =
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
    , aboveCard = Nothing
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
            , order = 2
            }
          )
        , ( 2
          , { id = 2
            , column = "todo"
            , order = 1
            }
          )
        , ( 3
          , { id = 3
            , column = "todo"
            , order = 3
            }
          )
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DragStart nodeId startPos ->
            ( { model
                | dragState = Moving nodeId startPos
                , startPos = startPos
              }
            , Cmd.none
            )

        ClickedCard ->
            ( model, Cmd.none )

        DragMove nodeId isDown position ->
            ( { model
                | dragState =
                    if isDown then
                        Moving nodeId position

                    else
                        Static
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
                , aboveCard = Nothing
              }
            , Cmd.none
            )

        ColumnEntered column ->
            let
                newCards =
                    case model.dragState of
                        Static ->
                            model.cards

                        Moving nodeId _ ->
                            setColumn model.cards nodeId column
            in
            ( { model | inColumn = Just column, cards = newCards }, Cmd.none )

        CardEntered cardId ->
            let
                newCards =
                    setOrder model cardId
            in
            ( { model | aboveCard = Just cardId, cards = newCards }, Cmd.none )


setColumn : Cards -> CardId -> Column -> Cards
setColumn cards nodeId column =
    case findCard nodeId cards of
        Just card ->
            insertCard nodeId { card | column = column } cards

        Nothing ->
            cards


setOrder : Model -> CardId -> Cards
setOrder model relativeCardId =
    let
        ( movingCardMaybe, goingUp ) =
            case model.dragState of
                Static ->
                    ( Nothing, False )

                Moving cardId position ->
                    ( findCard cardId model.cards, model.startPos.y > position.y )
    in
    case ( findCard relativeCardId model.cards, movingCardMaybe ) of
        ( Just relativeCard, Just movingCard ) ->
            if goingUp then
                model.cards
                    |> insertCard movingCard.id { movingCard | order = movingCard.order - 1 }
                    |> insertCard relativeCard.id { relativeCard | order = relativeCard.order + 1 }

            else
                model.cards
                    |> insertCard movingCard.id { movingCard | order = movingCard.order + 1 }
                    |> insertCard relativeCard.id { relativeCard | order = relativeCard.order -  1 }

        _ ->
            model.cards


findCard : CardId -> Cards -> Maybe TodoCard
findCard nodeId cards =
    Dict.get nodeId cards


insertCard : CardId -> TodoCard -> Cards -> Cards
insertCard nodeId card cards =
    Dict.insert nodeId card cards



-- View


view : Model -> Html.Html Msg
view model =
    div []
        [ div [ class "header" ]
            [ p [] [ text "Todo board with drag'n'drop" ]
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
            Dict.values model.cards
                |> List.filter (\card -> card.column == column)
                |> List.sortBy .order
                |> List.map (viewTodoCard model.dragState)

        classes =
            "card-column"
                ++ (if model.inColumn == Just column then
                        " in-column"

                    else
                        ""
                   )
    in
    case model.dragState of
        Static ->
            div [ class "card-column" ]
                cardsOfColumn

        Moving _ _ ->
            div [ class classes, onMouseEnter (ColumnEntered column) ]
                cardsOfColumn


viewTodoCard : DragState -> TodoCard -> Html.Html Msg
viewTodoCard dragState card =
    let
        cardContent =
            [ p [] [ text <| String.fromInt card.id ]
            ]
    in
    case dragState of
        Moving nodeId position ->
            if nodeId == card.id then
                div []
                    [ div
                        [ class "card card-dragged"
                        , style "left" (String.fromFloat position.x ++ "px")
                        , style "top" (String.fromFloat position.y ++ "px")
                        ]
                        cardContent
                    , div [ class "card shadow-card" ]
                        []
                    ]

            else
                div
                    [ class "card"
                    , onMouseEnter (CardEntered card.id)
                    ]
                    cardContent

        Static ->
            div
                [ class "card"
                , on "mousedown" (Decode.map (DragStart card.id) decodeClientPosition)
                ]
                cardContent



-- Subscription


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.dragState of
        Static ->
            Sub.none

        Moving id _ ->
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


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
