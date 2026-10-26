module Evergreen.V413.Game exposing (..)

import Array
import Evergreen.V413.Go
import Evergreen.V413.Id
import Evergreen.V413.Message
import Evergreen.V413.SecretId
import Evergreen.V413.SheepGame
import Evergreen.V413.UserSession
import Evergreen.V413.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V413.Go.GameMsg
    | GoSetupMsg Evergreen.V413.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V413.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V413.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V413.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V413.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V413.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V413.Go.ValidatedSetup (Array.Array Evergreen.V413.Go.ActionWithTime) Evergreen.V413.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V413.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V413.WordSpellingGame.ActionWithTime) Evergreen.V413.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V413.SheepGame.ValidatedSetup (Array.Array Evergreen.V413.SheepGame.ActionWithTime) Evergreen.V413.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V413.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V413.Go.ValidatedSetup (Array.Array Evergreen.V413.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V413.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V413.WordSpellingGame.ActionWithTime) Evergreen.V413.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V413.SheepGame.ValidatedSetup (Array.Array Evergreen.V413.SheepGame.ActionWithTime) Evergreen.V413.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.UserSession.ToBeFilledInByBackend (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.GamePublicId))
    | LoadMatch (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Evergreen.V413.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Evergreen.V413.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V413.Go.GameModel
    | WordSpellingGame_Game Evergreen.V413.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V413.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V413.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V413.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V413.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId, Evergreen.V413.SheepGame.Input ) Int
    }
