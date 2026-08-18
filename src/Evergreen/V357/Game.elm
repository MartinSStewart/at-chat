module Evergreen.V357.Game exposing (..)

import Array
import Evergreen.V357.Go
import Evergreen.V357.Id
import Evergreen.V357.Message
import Evergreen.V357.SecretId
import Evergreen.V357.SheepGame
import Evergreen.V357.UserSession
import Evergreen.V357.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V357.Go.GameMsg
    | GoSetupMsg Evergreen.V357.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V357.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V357.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V357.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V357.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V357.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V357.Go.ValidatedSetup (Array.Array Evergreen.V357.Go.ActionWithTime) Evergreen.V357.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V357.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V357.WordSpellingGame.ActionWithTime) Evergreen.V357.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V357.SheepGame.ValidatedSetup (Array.Array Evergreen.V357.SheepGame.ActionWithTime) Evergreen.V357.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Evergreen.V357.UserSession.ToBeFilledInByBackend (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Evergreen.V357.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V357.Go.GameModel
    | WordSpellingGame_Game Evergreen.V357.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V357.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V357.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V357.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V357.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V357.Go.ValidatedSetup (Array.Array Evergreen.V357.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V357.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V357.WordSpellingGame.ActionWithTime) Evergreen.V357.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V357.SheepGame.ValidatedSetup (Array.Array Evergreen.V357.SheepGame.ActionWithTime) Evergreen.V357.SheepGame.Shared
