﻿$Global:IE;

#********
# Common
#********

function init(){
    $Global:IE = New-Object -com internetexplorer.application;
    $Global:IE.visible = $true;
}

function play_video($url){
    $Global:IE.navigate2($url);
}
function clear_screen(){
    Clear-Host;
}
function get_request([string]$query){
    clear_screen;
    show_wait;

    $client = New-Object System.Net.WebClient
    $string = $client.DownloadString($query);
    
    return $string;
}

function is_Numeric ($x) {
    try {
        0 + $x | Out-Null
    } catch {
        return $FALSE
    }
    $value = "";
    if( ![int]::TryParse( $x, [ref]$value ) ){
        return $FALSE;
    }
    return $TRUE;
}

function show_wait(){
    Write-Host "Please wait...";
}

#********
# State
#********

$Global:currentState = "-1";
$Global:STATE_PENDING_QUERY="0";
$Global:STATE_PENDING_NUM="1"; 

function get_state(){
    return $Global:currentState;
}

function set_state($state){
    $Global:currentState = $state;
}

#********
# Input
#********

function select_video($parsed_videos){
    $url = get_video_url($parsed_videos);
    $state = get_state;
    if($state -eq $Global:STATE_PENDING_NUM){
        play_video($url);
        set_state($Global:STATE_PENDING_QUERY);
    }
}
function get_input(){
    #TODO error checking on input
    $url = Read-Host "What do you want to listen to (<Ctrl C> to quit): ";
    return $url;
}

function handle_input($user_input){
    $formatted_request = "https://www.googleapis.com/youtube/v3/search?q=$user_input&part=snippet&key=AIzaSyCrb1f-QjPwO9w-sB6qQTNdQ-vEdjMx7Ek&order=relevance&maxResults=10";
    $videos = get_videos($formatted_request);

    show_videos($videos);
    
    select_video($videos);
}

function show_videos($parsed_videos){
    for($index = 0;$index -lt $parsed_videos.length;$index++){
        Write-Host "[" $index "]" $parsed_videos[$index].title " - " $parsed_videos[$index].channel;
    }
    Write-Host
}

function get_video_url($parsed){    
    $id = "";
    $num = "";
    $canStop = $false;
    while($canStop -ne $true){
        $num = Read-Host "| number = video | <Enter> = search again | "
        if(!$num){
            $canStop = $true;
            set_state($Global:STATE_PENDING_QUERY);
        }
        elseif(is_Numeric($num) -and $num -ge 0 -and $num -le 9){
            
            $canStop = $true;
            $id = $parsed[$num].url;
        }
    }
    
    return "https://www.youtube.com/watch?v=$id";
}

function process_commands(){
    while($true){
        clear_screen;
        $user_input = get_input; 
        handle_input($user_input);
    }
}

#********
# Video data structure
#********

function get_new_video($video_channel,$video_title,$video_url){
    $new_video = New-Object psobject -Property @{
        channel = $video_channel
        title = $video_title
        url = $video_url
    };
    return $new_video;
}

#********
# Search
#********

function get_videos($query){
    set_state($Global:STATE_PENDING_NUM);
    $results = get_request($query);
    $parsed = parse_search_results($results);
    return $parsed;
}

function parse_search_results([string]$results){
    $videos = New-Object System.Collections.ArrayList;
    $json = ConvertFrom-Json $results;
    
    for($index = 0;$index -lt $json.items.length;$index++){
        $parsed_channel = $json.items[$index].snippet.channelTitle;
        $parsed_title = $json.items[$index].snippet.title;
        $parsed_id = $json.items[$index].id.videoId;
        
        $new_video = get_new_video $parsed_channel $parsed_title $parsed_id;
        [void]$videos.Add($new_video);
        
    }
    return $videos;
}

#********
# Entry Point
#********
init;
try{
process_commands;
}
finally{
    $Global:IE.Quit();
}