module Evergreen.V346.Game exposing (..)

import Array
import Evergreen.V346.Go
import Evergreen.V346.Id
import Evergreen.V346.Message
import Evergreen.V346.SecretId
import Evergreen.V346.UserSession
import Evergreen.V346.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V346.Go.GameMsg
    | GoSetupMsg Evergreen.V346.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V346.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V346.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V346.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V346.Go.ValidatedSetup (Array.Array Evergreen.V346.Go.ActionWithTime) Evergreen.V346.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V346.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V346.WordSpellingGame.ActionWithTime) Evergreen.V346.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Evergreen.V346.UserSession.ToBeFilledInByBackend (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Evergreen.V346.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V346.Go.GameModel
    | WordSpellingGame_Game Evergreen.V346.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V346.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V346.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V346.Go.ValidatedSetup (Array.Array Evergreen.V346.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V346.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V346.WordSpellingGame.ActionWithTime) Evergreen.V346.WordSpellingGame.Shared
