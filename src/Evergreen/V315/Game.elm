module Evergreen.V315.Game exposing (..)

import Array
import Evergreen.V315.Go
import Evergreen.V315.Id
import Evergreen.V315.Message
import Evergreen.V315.SecretId
import Evergreen.V315.UserSession
import Evergreen.V315.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V315.Go.GameMsg
    | GoSetupMsg Evergreen.V315.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V315.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V315.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V315.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V315.Go.ValidatedSetup (Array.Array Evergreen.V315.Go.ActionWithTime) Evergreen.V315.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V315.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V315.WordSpellingGame.ActionWithTime) Evergreen.V315.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Evergreen.V315.UserSession.ToBeFilledInByBackend (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Evergreen.V315.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V315.Go.GameModel
    | WordSpellingGame_Game Evergreen.V315.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V315.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V315.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V315.Go.ValidatedSetup (Array.Array Evergreen.V315.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V315.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V315.WordSpellingGame.ActionWithTime) Evergreen.V315.WordSpellingGame.Shared
