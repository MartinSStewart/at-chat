module Evergreen.V340.Game exposing (..)

import Array
import Evergreen.V340.Go
import Evergreen.V340.Id
import Evergreen.V340.Message
import Evergreen.V340.SecretId
import Evergreen.V340.UserSession
import Evergreen.V340.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V340.Go.GameMsg
    | GoSetupMsg Evergreen.V340.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V340.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V340.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V340.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V340.Go.ValidatedSetup (Array.Array Evergreen.V340.Go.ActionWithTime) Evergreen.V340.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V340.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V340.WordSpellingGame.ActionWithTime) Evergreen.V340.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Evergreen.V340.UserSession.ToBeFilledInByBackend (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V340.Go.GameModel
    | WordSpellingGame_Game Evergreen.V340.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V340.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V340.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V340.Go.ValidatedSetup (Array.Array Evergreen.V340.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V340.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V340.WordSpellingGame.ActionWithTime) Evergreen.V340.WordSpellingGame.Shared
