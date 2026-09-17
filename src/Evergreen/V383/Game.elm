module Evergreen.V383.Game exposing (..)

import Array
import Evergreen.V383.Go
import Evergreen.V383.Id
import Evergreen.V383.Message
import Evergreen.V383.SecretId
import Evergreen.V383.SheepGame
import Evergreen.V383.UserSession
import Evergreen.V383.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V383.Go.GameMsg
    | GoSetupMsg Evergreen.V383.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V383.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V383.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V383.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V383.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V383.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V383.Go.ValidatedSetup (Array.Array Evergreen.V383.Go.ActionWithTime) Evergreen.V383.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V383.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V383.WordSpellingGame.ActionWithTime) Evergreen.V383.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V383.SheepGame.ValidatedSetup (Array.Array Evergreen.V383.SheepGame.ActionWithTime) Evergreen.V383.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V383.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V383.Go.ValidatedSetup (Array.Array Evergreen.V383.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V383.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V383.WordSpellingGame.ActionWithTime) Evergreen.V383.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V383.SheepGame.ValidatedSetup (Array.Array Evergreen.V383.SheepGame.ActionWithTime) Evergreen.V383.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.UserSession.ToBeFilledInByBackend (Evergreen.V383.SecretId.SecretId Evergreen.V383.Id.GamePublicId))
    | LoadMatch (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) (Evergreen.V383.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Evergreen.V383.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V383.Go.GameModel
    | WordSpellingGame_Game Evergreen.V383.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V383.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V383.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V383.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V383.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId, Evergreen.V383.SheepGame.Input ) Int
    }
