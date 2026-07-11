module Evergreen.V313.Game exposing (..)

import Array
import Evergreen.V313.Go
import Evergreen.V313.Id
import Evergreen.V313.Message
import Evergreen.V313.SecretId
import Evergreen.V313.UserSession
import Evergreen.V313.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V313.Go.GameMsg
    | GoSetupMsg Evergreen.V313.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V313.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V313.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V313.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V313.Go.ValidatedSetup (Array.Array Evergreen.V313.Go.ActionWithTime) Evergreen.V313.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V313.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V313.WordSpellingGame.ActionWithTime) Evergreen.V313.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Evergreen.V313.UserSession.ToBeFilledInByBackend (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Evergreen.V313.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V313.Go.GameModel
    | WordSpellingGame_Game Evergreen.V313.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V313.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V313.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V313.Go.ValidatedSetup (Array.Array Evergreen.V313.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V313.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V313.WordSpellingGame.ActionWithTime) Evergreen.V313.WordSpellingGame.Shared
