module Evergreen.V312.Game exposing (..)

import Array
import Evergreen.V312.Go
import Evergreen.V312.Id
import Evergreen.V312.Message
import Evergreen.V312.SecretId
import Evergreen.V312.UserSession
import Evergreen.V312.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V312.Go.GameMsg
    | GoSetupMsg Evergreen.V312.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V312.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V312.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V312.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V312.Go.ValidatedSetup (Array.Array Evergreen.V312.Go.ActionWithTime) Evergreen.V312.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V312.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V312.WordSpellingGame.ActionWithTime) Evergreen.V312.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Evergreen.V312.UserSession.ToBeFilledInByBackend (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V312.Go.GameModel
    | WordSpellingGame_Game Evergreen.V312.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V312.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V312.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V312.Go.ValidatedSetup (Array.Array Evergreen.V312.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V312.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V312.WordSpellingGame.ActionWithTime) Evergreen.V312.WordSpellingGame.Shared
