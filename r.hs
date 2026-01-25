import System.Directory (listDirectory, doesFileExist)
import System.Process (readProcess)
import qualified Data.Set as Set
import Control.Concurrent (threadDelay)
import System.IO (hFlush, stdout)
import Text.Printf (printf)
import Control.Exception (catch, SomeException)

-- Definisi warna menggunakan format Hex \x1b (lebih stabil)
reset   = "\x1b[0m"
bold    = "\x1b[1m"
red     = "\x1b[1;31m"
green   = "\x1b[1;32m"
yellow  = "\x1b[1;33m"
cyan    = "\x1b[1;36m"
magenta = "\x1b[1;35m"
gray    = "\x1b[1;90m"

printHeader = do
    putStrLn "\x1b[2J\x1b[1;1H"
    putStrLn $ cyan ++ "╭──────────────────────────────────────────────╮" ++ reset
    putStrLn $ cyan ++ "│" ++ magenta ++ " (｡•̀ᴗ-)✧    VERSA SECURITY (HSL)         " ++ cyan ++ "   │" ++ reset
    putStrLn $ cyan ++ "│" ++ gray ++ " ~~~~~~~    Deep Process Inspector        " ++ cyan ++ "   │" ++ reset
    putStrLn $ cyan ++ "╰──────────────────────────────────────────────╯" ++ reset ++ "\n"

showLoading text = do
    putStr $ text ++ " ["
    mapM_ (\_ -> putStr (green ++ "▓" ++ reset) >> hFlush stdout >> threadDelay 30000) [1..20]
    putStrLn $ "] " ++ green ++ "DONE!" ++ reset

getPsPids = do
    output <- readProcess "ps" ["-e", "-o", "pid"] ""
    let rows = drop 1 $ lines output
    return $ Set.fromList [p | r <- rows, let p = filter (not . (`elem` " \t")) r, not (null p)]

getProcPids = do
    contents <- listDirectory "/proc"
    return $ Set.fromList [c | c <- contents, all (`elem` ['0'..'9']) c]

getProcName pid = do
    let path = "/proc/" ++ pid ++ "/comm"
    exists <- doesFileExist path
    if exists 
        then (readFile path >>= \content -> return $ head (lines content ++ ["???"])) `catch` (\(_ :: SomeException) -> return "???")
        else return "???"

main = do
    printHeader
    
    putStrLn $ gray ++ " Initializing Kernel Module View..." ++ reset
    showLoading " Scanning /proc"
    
    putStrLn $ gray ++ " Executing Userland Check (ps)..." ++ reset
    showLoading " Parsing output"

    psPids <- getPsPids
    procPids <- getProcPids

    let allPids = Set.toList $ Set.union psPids procPids
    
    putStrLn $ "\n" ++ bold ++ "  PID     NAME                STATUS" ++ reset
    putStrLn $ cyan ++ "  ─────── ─────────────────── ──────────────────" ++ reset

    results <- mapM (\pid -> do
        let inPs = Set.member pid psPids
        let inProc = Set.member pid procPids
        name <- if inProc then getProcName pid else return "???"
        return (pid, name, inPs, inProc)) allPids

    let filtered = filter (\(_, _, ips, ipr) -> not (ips && ipr)) results
    
    mapM_ (\(pid, name, ips, ipr) -> do
        let (status, color) = if not ips && ipr 
                                then ("⚠ HIDDEN (ROOTKIT?)", red ++ bold)
                                else ("⚡ DIED (Race Cond)", yellow)
        printf "  %-8s %-19s %s%s%s\n" pid name color status reset) filtered

    if null filtered
        then putStrLn $ green ++ "  [INFO] All processes matched. System clean." ++ reset
        else return ()

    putStrLn $ cyan ++ "  ──────────────────────────────────────────────" ++ reset
    putStrLn $ "  " ++ bold ++ "SCAN SUMMARY:" ++ reset
    
    let hidden = filter (\(_, _, ips, ipr) -> not ips && ipr) filtered
    if not (null hidden)
        then do
            putStrLn $ "  Status: " ++ red ++ bold ++ "THREAT DETECTED" ++ reset
            putStrLn $ "  Action: " ++ red ++ "Investigate HIDDEN processes." ++ reset
        else do
            putStrLn $ "  Status: " ++ green ++ "SECURE" ++ reset
            putStrLn $ "  Note  : " ++ gray ++ show (length filtered) ++ " process(es) died during scan." ++ reset
    
    putStrLn ""

