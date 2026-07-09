module Evergreen.V308.Game exposing (..)

import Array
import Evergreen.V308.Go
import Evergreen.V308.Id
import Evergreen.V308.Message
import Evergreen.V308.SecretId
import Evergreen.V308.UserSession
import Evergreen.V308.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V308.Go.GameMsg
    | GoSetupMsg Evergreen.V308.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V308.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V308.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V308.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V308.Go.ValidatedSetup (Array.Array Evergreen.V308.Go.ActionWithTime) Evergreen.V308.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V308.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V308.WordSpellingGame.ActionWithTime) Evergreen.V308.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Evergreen.V308.UserSession.ToBeFilledInByBackend (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V308.Go.GameModel
    | WordSpellingGame_Game Evergreen.V308.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V308.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V308.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V308.Go.ValidatedSetup (Array.Array Evergreen.V308.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V308.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V308.WordSpellingGame.ActionWithTime) Evergreen.V308.WordSpellingGame.Shared
