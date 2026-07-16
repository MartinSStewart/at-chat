module Evergreen.V326.Game exposing (..)

import Array
import Evergreen.V326.Go
import Evergreen.V326.Id
import Evergreen.V326.Message
import Evergreen.V326.SecretId
import Evergreen.V326.UserSession
import Evergreen.V326.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V326.Go.GameMsg
    | GoSetupMsg Evergreen.V326.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V326.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V326.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V326.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V326.Go.ValidatedSetup (Array.Array Evergreen.V326.Go.ActionWithTime) Evergreen.V326.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V326.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V326.WordSpellingGame.ActionWithTime) Evergreen.V326.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Evergreen.V326.UserSession.ToBeFilledInByBackend (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V326.Go.GameModel
    | WordSpellingGame_Game Evergreen.V326.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V326.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V326.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V326.Go.ValidatedSetup (Array.Array Evergreen.V326.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V326.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V326.WordSpellingGame.ActionWithTime) Evergreen.V326.WordSpellingGame.Shared
