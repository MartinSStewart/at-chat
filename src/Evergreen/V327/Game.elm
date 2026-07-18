module Evergreen.V327.Game exposing (..)

import Array
import Evergreen.V327.Go
import Evergreen.V327.Id
import Evergreen.V327.Message
import Evergreen.V327.SecretId
import Evergreen.V327.UserSession
import Evergreen.V327.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V327.Go.GameMsg
    | GoSetupMsg Evergreen.V327.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V327.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V327.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V327.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V327.Go.ValidatedSetup (Array.Array Evergreen.V327.Go.ActionWithTime) Evergreen.V327.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V327.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V327.WordSpellingGame.ActionWithTime) Evergreen.V327.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Evergreen.V327.UserSession.ToBeFilledInByBackend (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Evergreen.V327.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V327.Go.GameModel
    | WordSpellingGame_Game Evergreen.V327.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V327.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V327.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V327.Go.ValidatedSetup (Array.Array Evergreen.V327.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V327.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V327.WordSpellingGame.ActionWithTime) Evergreen.V327.WordSpellingGame.Shared
