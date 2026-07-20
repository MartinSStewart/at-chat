module Evergreen.V330.Game exposing (..)

import Array
import Evergreen.V330.Go
import Evergreen.V330.Id
import Evergreen.V330.Message
import Evergreen.V330.SecretId
import Evergreen.V330.UserSession
import Evergreen.V330.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V330.Go.GameMsg
    | GoSetupMsg Evergreen.V330.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V330.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V330.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V330.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V330.Go.ValidatedSetup (Array.Array Evergreen.V330.Go.ActionWithTime) Evergreen.V330.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V330.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V330.WordSpellingGame.ActionWithTime) Evergreen.V330.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Evergreen.V330.UserSession.ToBeFilledInByBackend (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Evergreen.V330.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V330.Go.GameModel
    | WordSpellingGame_Game Evergreen.V330.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V330.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V330.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V330.Go.ValidatedSetup (Array.Array Evergreen.V330.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V330.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V330.WordSpellingGame.ActionWithTime) Evergreen.V330.WordSpellingGame.Shared
