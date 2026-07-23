module Evergreen.V333.Game exposing (..)

import Array
import Evergreen.V333.Go
import Evergreen.V333.Id
import Evergreen.V333.Message
import Evergreen.V333.SecretId
import Evergreen.V333.UserSession
import Evergreen.V333.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V333.Go.GameMsg
    | GoSetupMsg Evergreen.V333.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V333.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V333.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V333.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V333.Go.ValidatedSetup (Array.Array Evergreen.V333.Go.ActionWithTime) Evergreen.V333.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V333.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V333.WordSpellingGame.ActionWithTime) Evergreen.V333.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Evergreen.V333.UserSession.ToBeFilledInByBackend (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V333.Go.GameModel
    | WordSpellingGame_Game Evergreen.V333.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V333.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V333.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V333.Go.ValidatedSetup (Array.Array Evergreen.V333.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V333.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V333.WordSpellingGame.ActionWithTime) Evergreen.V333.WordSpellingGame.Shared
