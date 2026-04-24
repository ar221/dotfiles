function ocp --description 'Launch OpenCode plan agent on the Claude Sonnet lane'
    oc $argv --agent plan --model claude-proxy/claude-sonnet-4-6
end
