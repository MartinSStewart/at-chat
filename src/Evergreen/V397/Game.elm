module Evergreen.V397.Game exposing (..)

import Array
import Evergreen.V397.Go
import Evergreen.V397.Id
import Evergreen.V397.Message
import Evergreen.V397.SecretId
import Evergreen.V397.SheepGame
import Evergreen.V397.UserSession
import Evergreen.V397.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V397.Go.GameMsg
    | GoSetupMsg Evergreen.V397.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V397.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V397.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V397.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V397.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V397.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V397.Go.ValidatedSetup (Array.Array Evergreen.V397.Go.ActionWithTime) Evergreen.V397.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V397.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V397.WordSpellingGame.ActionWithTime) Evergreen.V397.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V397.SheepGame.ValidatedSetup (Array.Array Evergreen.V397.SheepGame.ActionWithTime) Evergreen.V397.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V397.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V397.Go.ValidatedSetup (Array.Array Evergreen.V397.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V397.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V397.WordSpellingGame.ActionWithTime) Evergreen.V397.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V397.SheepGame.ValidatedSetup (Array.Array Evergreen.V397.SheepGame.ActionWithTime) Evergreen.V397.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.UserSession.ToBeFilledInByBackend (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.GamePublicId))
    | LoadMatch (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Evergreen.V397.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Evergreen.V397.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V397.Go.GameModel
    | WordSpellingGame_Game Evergreen.V397.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V397.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V397.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V397.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V397.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId, Evergreen.V397.SheepGame.Input ) Int
    }
