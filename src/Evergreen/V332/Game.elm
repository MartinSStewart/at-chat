module Evergreen.V332.Game exposing (..)

import Array
import Evergreen.V332.Go
import Evergreen.V332.Id
import Evergreen.V332.Message
import Evergreen.V332.SecretId
import Evergreen.V332.UserSession
import Evergreen.V332.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V332.Go.GameMsg
    | GoSetupMsg Evergreen.V332.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V332.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V332.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V332.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V332.Go.ValidatedSetup (Array.Array Evergreen.V332.Go.ActionWithTime) Evergreen.V332.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V332.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V332.WordSpellingGame.ActionWithTime) Evergreen.V332.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Evergreen.V332.UserSession.ToBeFilledInByBackend (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V332.Go.GameModel
    | WordSpellingGame_Game Evergreen.V332.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V332.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V332.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V332.Go.ValidatedSetup (Array.Array Evergreen.V332.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V332.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V332.WordSpellingGame.ActionWithTime) Evergreen.V332.WordSpellingGame.Shared
