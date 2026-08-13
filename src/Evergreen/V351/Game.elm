module Evergreen.V351.Game exposing (..)

import Array
import Evergreen.V351.Go
import Evergreen.V351.Id
import Evergreen.V351.Message
import Evergreen.V351.SecretId
import Evergreen.V351.UserSession
import Evergreen.V351.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V351.Go.GameMsg
    | GoSetupMsg Evergreen.V351.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V351.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V351.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V351.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V351.Go.ValidatedSetup (Array.Array Evergreen.V351.Go.ActionWithTime) Evergreen.V351.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V351.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V351.WordSpellingGame.ActionWithTime) Evergreen.V351.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Evergreen.V351.UserSession.ToBeFilledInByBackend (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Evergreen.V351.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V351.Go.GameModel
    | WordSpellingGame_Game Evergreen.V351.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V351.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V351.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V351.Go.ValidatedSetup (Array.Array Evergreen.V351.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V351.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V351.WordSpellingGame.ActionWithTime) Evergreen.V351.WordSpellingGame.Shared
