module Evergreen.V421.Game exposing (..)

import Array
import Evergreen.V421.Go
import Evergreen.V421.Id
import Evergreen.V421.Message
import Evergreen.V421.SecretId
import Evergreen.V421.SheepGame
import Evergreen.V421.UserSession
import Evergreen.V421.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V421.Go.GameMsg
    | GoSetupMsg Evergreen.V421.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V421.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V421.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V421.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V421.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V421.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V421.Go.ValidatedSetup (Array.Array Evergreen.V421.Go.ActionWithTime) Evergreen.V421.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V421.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V421.WordSpellingGame.ActionWithTime) Evergreen.V421.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V421.SheepGame.ValidatedSetup (Array.Array Evergreen.V421.SheepGame.ActionWithTime) Evergreen.V421.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V421.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V421.Go.ValidatedSetup (Array.Array Evergreen.V421.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V421.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V421.WordSpellingGame.ActionWithTime) Evergreen.V421.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V421.SheepGame.ValidatedSetup (Array.Array Evergreen.V421.SheepGame.ActionWithTime) Evergreen.V421.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.UserSession.ToBeFilledInByBackend (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.GamePublicId))
    | LoadMatch (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Evergreen.V421.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Evergreen.V421.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V421.Go.GameModel
    | WordSpellingGame_Game Evergreen.V421.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V421.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V421.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V421.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V421.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId, Evergreen.V421.SheepGame.Input ) Int
    }
