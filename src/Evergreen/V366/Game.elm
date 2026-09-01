module Evergreen.V366.Game exposing (..)

import Array
import Evergreen.V366.Go
import Evergreen.V366.Id
import Evergreen.V366.Message
import Evergreen.V366.SecretId
import Evergreen.V366.SheepGame
import Evergreen.V366.UserSession
import Evergreen.V366.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V366.Go.GameMsg
    | GoSetupMsg Evergreen.V366.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V366.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V366.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V366.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V366.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V366.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V366.Go.ValidatedSetup (Array.Array Evergreen.V366.Go.ActionWithTime) Evergreen.V366.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V366.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V366.WordSpellingGame.ActionWithTime) Evergreen.V366.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V366.SheepGame.ValidatedSetup (Array.Array Evergreen.V366.SheepGame.ActionWithTime) Evergreen.V366.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V366.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V366.Go.ValidatedSetup (Array.Array Evergreen.V366.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V366.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V366.WordSpellingGame.ActionWithTime) Evergreen.V366.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V366.SheepGame.ValidatedSetup (Array.Array Evergreen.V366.SheepGame.ActionWithTime) Evergreen.V366.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.UserSession.ToBeFilledInByBackend (Evergreen.V366.SecretId.SecretId Evergreen.V366.Id.GamePublicId))
    | LoadMatch (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) (Evergreen.V366.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Evergreen.V366.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V366.Go.GameModel
    | WordSpellingGame_Game Evergreen.V366.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V366.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V366.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V366.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V366.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId, Evergreen.V366.SheepGame.Input ) Int
    }
