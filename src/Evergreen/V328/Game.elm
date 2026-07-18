module Evergreen.V328.Game exposing (..)

import Array
import Evergreen.V328.Go
import Evergreen.V328.Id
import Evergreen.V328.Message
import Evergreen.V328.SecretId
import Evergreen.V328.UserSession
import Evergreen.V328.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V328.Go.GameMsg
    | GoSetupMsg Evergreen.V328.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V328.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V328.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V328.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V328.Go.ValidatedSetup (Array.Array Evergreen.V328.Go.ActionWithTime) Evergreen.V328.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V328.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V328.WordSpellingGame.ActionWithTime) Evergreen.V328.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V328.SecretId.SecretId Evergreen.V328.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (Evergreen.V328.UserSession.ToBeFilledInByBackend (Evergreen.V328.SecretId.SecretId Evergreen.V328.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Evergreen.V328.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V328.Go.GameModel
    | WordSpellingGame_Game Evergreen.V328.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V328.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V328.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V328.Go.ValidatedSetup (Array.Array Evergreen.V328.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V328.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V328.WordSpellingGame.ActionWithTime) Evergreen.V328.WordSpellingGame.Shared
