module Evergreen.V386.Game exposing (..)

import Array
import Evergreen.V386.Go
import Evergreen.V386.Id
import Evergreen.V386.Message
import Evergreen.V386.SecretId
import Evergreen.V386.SheepGame
import Evergreen.V386.UserSession
import Evergreen.V386.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V386.Go.GameMsg
    | GoSetupMsg Evergreen.V386.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V386.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V386.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V386.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V386.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V386.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V386.Go.ValidatedSetup (Array.Array Evergreen.V386.Go.ActionWithTime) Evergreen.V386.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V386.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V386.WordSpellingGame.ActionWithTime) Evergreen.V386.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V386.SheepGame.ValidatedSetup (Array.Array Evergreen.V386.SheepGame.ActionWithTime) Evergreen.V386.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V386.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V386.Go.ValidatedSetup (Array.Array Evergreen.V386.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V386.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V386.WordSpellingGame.ActionWithTime) Evergreen.V386.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V386.SheepGame.ValidatedSetup (Array.Array Evergreen.V386.SheepGame.ActionWithTime) Evergreen.V386.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.UserSession.ToBeFilledInByBackend (Evergreen.V386.SecretId.SecretId Evergreen.V386.Id.GamePublicId))
    | LoadMatch (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Evergreen.V386.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Evergreen.V386.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V386.Go.GameModel
    | WordSpellingGame_Game Evergreen.V386.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V386.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V386.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V386.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V386.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId, Evergreen.V386.SheepGame.Input ) Int
    }
