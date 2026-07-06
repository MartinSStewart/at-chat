module Evergreen.V304.Game exposing (..)

import Array
import Evergreen.V304.Go
import Evergreen.V304.Id
import Evergreen.V304.Message
import Evergreen.V304.SecretId
import Evergreen.V304.UserSession
import Evergreen.V304.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V304.Go.GameMsg
    | GoSetupMsg Evergreen.V304.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V304.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V304.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V304.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V304.Go.ValidatedSetup (Array.Array Evergreen.V304.Go.ActionWithTime) Evergreen.V304.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V304.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V304.WordSpellingGame.ActionWithTime) Evergreen.V304.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Evergreen.V304.UserSession.ToBeFilledInByBackend (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V304.Go.GameModel
    | WordSpellingGame_Game Evergreen.V304.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V304.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V304.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V304.Go.ValidatedSetup (Array.Array Evergreen.V304.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V304.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V304.WordSpellingGame.ActionWithTime) Evergreen.V304.WordSpellingGame.Shared
