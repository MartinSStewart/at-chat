module Evergreen.V396.Game exposing (..)

import Array
import Evergreen.V396.Go
import Evergreen.V396.Id
import Evergreen.V396.Message
import Evergreen.V396.SecretId
import Evergreen.V396.SheepGame
import Evergreen.V396.UserSession
import Evergreen.V396.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V396.Go.GameMsg
    | GoSetupMsg Evergreen.V396.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V396.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V396.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V396.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V396.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V396.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V396.Go.ValidatedSetup (Array.Array Evergreen.V396.Go.ActionWithTime) Evergreen.V396.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V396.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V396.WordSpellingGame.ActionWithTime) Evergreen.V396.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V396.SheepGame.ValidatedSetup (Array.Array Evergreen.V396.SheepGame.ActionWithTime) Evergreen.V396.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V396.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V396.Go.ValidatedSetup (Array.Array Evergreen.V396.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V396.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V396.WordSpellingGame.ActionWithTime) Evergreen.V396.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V396.SheepGame.ValidatedSetup (Array.Array Evergreen.V396.SheepGame.ActionWithTime) Evergreen.V396.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.UserSession.ToBeFilledInByBackend (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.GamePublicId))
    | LoadMatch (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Evergreen.V396.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Evergreen.V396.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V396.Go.GameModel
    | WordSpellingGame_Game Evergreen.V396.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V396.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V396.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V396.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V396.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId, Evergreen.V396.SheepGame.Input ) Int
    }
