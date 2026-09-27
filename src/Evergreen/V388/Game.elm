module Evergreen.V388.Game exposing (..)

import Array
import Evergreen.V388.Go
import Evergreen.V388.Id
import Evergreen.V388.Message
import Evergreen.V388.SecretId
import Evergreen.V388.SheepGame
import Evergreen.V388.UserSession
import Evergreen.V388.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V388.Go.GameMsg
    | GoSetupMsg Evergreen.V388.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V388.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V388.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V388.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V388.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V388.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V388.Go.ValidatedSetup (Array.Array Evergreen.V388.Go.ActionWithTime) Evergreen.V388.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V388.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V388.WordSpellingGame.ActionWithTime) Evergreen.V388.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V388.SheepGame.ValidatedSetup (Array.Array Evergreen.V388.SheepGame.ActionWithTime) Evergreen.V388.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V388.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V388.Go.ValidatedSetup (Array.Array Evergreen.V388.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V388.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V388.WordSpellingGame.ActionWithTime) Evergreen.V388.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V388.SheepGame.ValidatedSetup (Array.Array Evergreen.V388.SheepGame.ActionWithTime) Evergreen.V388.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.UserSession.ToBeFilledInByBackend (Evergreen.V388.SecretId.SecretId Evergreen.V388.Id.GamePublicId))
    | LoadMatch (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Evergreen.V388.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Evergreen.V388.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V388.Go.GameModel
    | WordSpellingGame_Game Evergreen.V388.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V388.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V388.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V388.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V388.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId, Evergreen.V388.SheepGame.Input ) Int
    }
