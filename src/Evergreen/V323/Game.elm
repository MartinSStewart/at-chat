module Evergreen.V323.Game exposing (..)

import Array
import Evergreen.V323.Go
import Evergreen.V323.Id
import Evergreen.V323.Message
import Evergreen.V323.SecretId
import Evergreen.V323.UserSession
import Evergreen.V323.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V323.Go.GameMsg
    | GoSetupMsg Evergreen.V323.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V323.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V323.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V323.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V323.Go.ValidatedSetup (Array.Array Evergreen.V323.Go.ActionWithTime) Evergreen.V323.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V323.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V323.WordSpellingGame.ActionWithTime) Evergreen.V323.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.UserSession.ToBeFilledInByBackend (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V323.Go.GameModel
    | WordSpellingGame_Game Evergreen.V323.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V323.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V323.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V323.Go.ValidatedSetup (Array.Array Evergreen.V323.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V323.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V323.WordSpellingGame.ActionWithTime) Evergreen.V323.WordSpellingGame.Shared
