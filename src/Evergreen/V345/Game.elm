module Evergreen.V345.Game exposing (..)

import Array
import Evergreen.V345.Go
import Evergreen.V345.Id
import Evergreen.V345.Message
import Evergreen.V345.SecretId
import Evergreen.V345.UserSession
import Evergreen.V345.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V345.Go.GameMsg
    | GoSetupMsg Evergreen.V345.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V345.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V345.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V345.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V345.Go.ValidatedSetup (Array.Array Evergreen.V345.Go.ActionWithTime) Evergreen.V345.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V345.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V345.WordSpellingGame.ActionWithTime) Evergreen.V345.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Evergreen.V345.UserSession.ToBeFilledInByBackend (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Evergreen.V345.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V345.Go.GameModel
    | WordSpellingGame_Game Evergreen.V345.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V345.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V345.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V345.Go.ValidatedSetup (Array.Array Evergreen.V345.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V345.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V345.WordSpellingGame.ActionWithTime) Evergreen.V345.WordSpellingGame.Shared
