module Evergreen.V376.Game exposing (..)

import Array
import Evergreen.V376.Go
import Evergreen.V376.Id
import Evergreen.V376.Message
import Evergreen.V376.SecretId
import Evergreen.V376.SheepGame
import Evergreen.V376.UserSession
import Evergreen.V376.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V376.Go.GameMsg
    | GoSetupMsg Evergreen.V376.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V376.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V376.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V376.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V376.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V376.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V376.Go.ValidatedSetup (Array.Array Evergreen.V376.Go.ActionWithTime) Evergreen.V376.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V376.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V376.WordSpellingGame.ActionWithTime) Evergreen.V376.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V376.SheepGame.ValidatedSetup (Array.Array Evergreen.V376.SheepGame.ActionWithTime) Evergreen.V376.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V376.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V376.Go.ValidatedSetup (Array.Array Evergreen.V376.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V376.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V376.WordSpellingGame.ActionWithTime) Evergreen.V376.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V376.SheepGame.ValidatedSetup (Array.Array Evergreen.V376.SheepGame.ActionWithTime) Evergreen.V376.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.UserSession.ToBeFilledInByBackend (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.GamePublicId))
    | LoadMatch (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Evergreen.V376.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Evergreen.V376.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V376.Go.GameModel
    | WordSpellingGame_Game Evergreen.V376.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V376.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V376.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V376.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V376.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId, Evergreen.V376.SheepGame.Input ) Int
    }
