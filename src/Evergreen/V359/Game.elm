module Evergreen.V359.Game exposing (..)

import Array
import Evergreen.V359.Go
import Evergreen.V359.Id
import Evergreen.V359.Message
import Evergreen.V359.SecretId
import Evergreen.V359.SheepGame
import Evergreen.V359.UserSession
import Evergreen.V359.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V359.Go.GameMsg
    | GoSetupMsg Evergreen.V359.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V359.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V359.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V359.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V359.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V359.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V359.Go.ValidatedSetup (Array.Array Evergreen.V359.Go.ActionWithTime) Evergreen.V359.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V359.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V359.WordSpellingGame.ActionWithTime) Evergreen.V359.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V359.SheepGame.ValidatedSetup (Array.Array Evergreen.V359.SheepGame.ActionWithTime) Evergreen.V359.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Evergreen.V359.UserSession.ToBeFilledInByBackend (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V359.Go.GameModel
    | WordSpellingGame_Game Evergreen.V359.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V359.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V359.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V359.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V359.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V359.Go.ValidatedSetup (Array.Array Evergreen.V359.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V359.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V359.WordSpellingGame.ActionWithTime) Evergreen.V359.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V359.SheepGame.ValidatedSetup (Array.Array Evergreen.V359.SheepGame.ActionWithTime) Evergreen.V359.SheepGame.Shared
