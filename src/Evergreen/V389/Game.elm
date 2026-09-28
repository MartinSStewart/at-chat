module Evergreen.V389.Game exposing (..)

import Array
import Evergreen.V389.Go
import Evergreen.V389.Id
import Evergreen.V389.Message
import Evergreen.V389.SecretId
import Evergreen.V389.SheepGame
import Evergreen.V389.UserSession
import Evergreen.V389.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V389.Go.GameMsg
    | GoSetupMsg Evergreen.V389.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V389.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V389.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V389.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V389.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V389.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V389.Go.ValidatedSetup (Array.Array Evergreen.V389.Go.ActionWithTime) Evergreen.V389.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V389.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V389.WordSpellingGame.ActionWithTime) Evergreen.V389.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V389.SheepGame.ValidatedSetup (Array.Array Evergreen.V389.SheepGame.ActionWithTime) Evergreen.V389.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V389.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V389.Go.ValidatedSetup (Array.Array Evergreen.V389.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V389.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V389.WordSpellingGame.ActionWithTime) Evergreen.V389.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V389.SheepGame.ValidatedSetup (Array.Array Evergreen.V389.SheepGame.ActionWithTime) Evergreen.V389.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.UserSession.ToBeFilledInByBackend (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.GamePublicId))
    | LoadMatch (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Evergreen.V389.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Evergreen.V389.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V389.Go.GameModel
    | WordSpellingGame_Game Evergreen.V389.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V389.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V389.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V389.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V389.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId, Evergreen.V389.SheepGame.Input ) Int
    }
