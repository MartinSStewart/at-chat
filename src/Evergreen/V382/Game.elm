module Evergreen.V382.Game exposing (..)

import Array
import Evergreen.V382.Go
import Evergreen.V382.Id
import Evergreen.V382.Message
import Evergreen.V382.SecretId
import Evergreen.V382.SheepGame
import Evergreen.V382.UserSession
import Evergreen.V382.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V382.Go.GameMsg
    | GoSetupMsg Evergreen.V382.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V382.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V382.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V382.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V382.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V382.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V382.Go.ValidatedSetup (Array.Array Evergreen.V382.Go.ActionWithTime) Evergreen.V382.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V382.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V382.WordSpellingGame.ActionWithTime) Evergreen.V382.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V382.SheepGame.ValidatedSetup (Array.Array Evergreen.V382.SheepGame.ActionWithTime) Evergreen.V382.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V382.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V382.Go.ValidatedSetup (Array.Array Evergreen.V382.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V382.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V382.WordSpellingGame.ActionWithTime) Evergreen.V382.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V382.SheepGame.ValidatedSetup (Array.Array Evergreen.V382.SheepGame.ActionWithTime) Evergreen.V382.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.UserSession.ToBeFilledInByBackend (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.GamePublicId))
    | LoadMatch (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Evergreen.V382.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Evergreen.V382.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V382.Go.GameModel
    | WordSpellingGame_Game Evergreen.V382.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V382.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V382.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V382.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V382.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId, Evergreen.V382.SheepGame.Input ) Int
    }
