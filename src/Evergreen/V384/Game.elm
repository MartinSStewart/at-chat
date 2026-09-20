module Evergreen.V384.Game exposing (..)

import Array
import Evergreen.V384.Go
import Evergreen.V384.Id
import Evergreen.V384.Message
import Evergreen.V384.SecretId
import Evergreen.V384.SheepGame
import Evergreen.V384.UserSession
import Evergreen.V384.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V384.Go.GameMsg
    | GoSetupMsg Evergreen.V384.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V384.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V384.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V384.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V384.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V384.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V384.Go.ValidatedSetup (Array.Array Evergreen.V384.Go.ActionWithTime) Evergreen.V384.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V384.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V384.WordSpellingGame.ActionWithTime) Evergreen.V384.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V384.SheepGame.ValidatedSetup (Array.Array Evergreen.V384.SheepGame.ActionWithTime) Evergreen.V384.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V384.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V384.Go.ValidatedSetup (Array.Array Evergreen.V384.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V384.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V384.WordSpellingGame.ActionWithTime) Evergreen.V384.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V384.SheepGame.ValidatedSetup (Array.Array Evergreen.V384.SheepGame.ActionWithTime) Evergreen.V384.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.UserSession.ToBeFilledInByBackend (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.GamePublicId))
    | LoadMatch (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Evergreen.V384.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Evergreen.V384.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V384.Go.GameModel
    | WordSpellingGame_Game Evergreen.V384.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V384.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V384.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V384.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V384.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId, Evergreen.V384.SheepGame.Input ) Int
    }
