//
//  GameScene.swift
//  MetalBreakOut
//
//  Created by Gabriel Lewis on 4/19/18.
//  Copyright © 2018 Gabriel Lewis. All rights reserved.
//

import MetalKit
import AVFoundation

class GameScene: Scene {

    struct GameConstants {
        static let gameHeight: Float = 48
        static let gameWidth: Float = 27
        static let bricksPerRow = 8
        static let bricksPerColumn = 8
    }

    var ballVelocityX: Float = 0
    var ballVelocityY: Float = 0

    let ball: Model
    let paddle: Model

    let bricks: Instance

    override init(device: MTLDevice, size: CGSize) {
        ball = Model(device: device, modelName: "ball")
        paddle = Model(device: device, modelName: "paddle")
        let numberOfBricks = GameConstants.bricksPerColumn * GameConstants.bricksPerRow
        bricks = Instance(device: device, modelName: "brick", instances: numberOfBricks)
        super.init(device: device, size: size)

        // set the correct offset of the scene from camera given height of scene
        camera.position.z = -sceneOffset(height: GameConstants.gameHeight, fov: camera.fovRadians)

        // set the camera position offset from the bottom left corner of the screen (making all values positive)
        camera.position.x = -GameConstants.gameWidth / 2
        camera.position.y = -GameConstants.gameHeight / 2
        camera.rotation.x = radians(fromDegrees: 28)
        camera.position.y = -GameConstants.gameHeight / 2 + 5

        setupLighting()
        setupScene()
    }

    private func setupLighting() {
        light.color = float3(1, 1, 1)
        light.ambientIntensity = 0.3
        light.diffuseIntensity = 0.8
        light.direction = float3(0, -1, -1)
    }

    private func setupScene() {
        ballVelocityX = 20
        ballVelocityY = 15
        ball.position.x = GameConstants.gameWidth / 2
        ball.position.y = GameConstants.gameHeight * 0.1
        ball.materialColor = float4(0.5, 0.9, 0, 1)
        add(childNode: ball)

        paddle.position.x = GameConstants.gameWidth / 2
        paddle.position.y = GameConstants.gameHeight * 0.05
        paddle.materialColor = float4(1, 0, 0, 1)
        add(childNode: paddle)

        let border = Model(device: device, modelName: "border")
        border.position.x = GameConstants.gameWidth / 2
        border.position.y = GameConstants.gameHeight / 2
        border.materialColor = float4(0, 0, 0, 1)
        add(childNode: border)


        let colors = generateColors(number: GameConstants.bricksPerRow)
        let margin = GameConstants.gameWidth * 0.11
        let startY = GameConstants.gameHeight * 0.5

        for row in 0..<GameConstants.bricksPerRow {
            for column in 0..<GameConstants.bricksPerColumn {
                var position = float3(0)
                position.x = margin + (margin * Float(row))
                position.y = startY + (margin * Float(column))
                let index = row * GameConstants.bricksPerColumn + column
                bricks.nodes[index].position = position
                bricks.nodes[index].materialColor = colors[row]
            }
        }
        add(childNode: bricks)
    }


    override func update(deltaTime: Float) {
        var bounced = false
        var popped = false
        for brick in bricks.nodes {
            brick.rotation.y += .pi / 4 * deltaTime
            brick.rotation.z += .pi / 4 * deltaTime
        }
        ball.position.x += ballVelocityX * deltaTime
        ball.position.y += ballVelocityY * deltaTime

        if ball.position.y > GameConstants.gameHeight {
            ball.position.y = GameConstants.gameHeight
            ballVelocityY = -ballVelocityY
            bounced = true
        }

        if ball.position.x < 0 {
            ball.position.x = 0
            ballVelocityX = -ballVelocityX
            bounced = true
        }

        if ball.position.x > GameConstants.gameWidth {
            ball.position.x = GameConstants.gameWidth
            ballVelocityX = -ballVelocityX
            bounced = true
        }

        if ball.position.y < 0 {
            ballVelocityY = -ballVelocityY
            bounced = true
        }

        let ballRect = ball.boundingBox(camera.viewMatrix)
        let paddleRect = paddle.boundingBox(camera.viewMatrix)

        if ballRect.intersects(paddleRect) {
            ballVelocityY = -ballVelocityY
            bounced = true
        }

        for (index, brick) in bricks.nodes.enumerated() {
            let brickRect = brick.boundingBox(camera.viewMatrix)
            if ballRect.intersects(brickRect) {
                bounced = true
                bricks.remove(instance: index)
                ballVelocityY = -ballVelocityY
            }
        }

//        if bounced {
//            let systemSoundID: SystemSoundID = 1110
//            AudioServicesPlaySystemSound (systemSoundID)
//        }
    }

    private func sceneOffset(height: Float, fov: Float) -> Float {
        return (height / 2) / tan(fov / 2)
    }

    override func touchesBegan(_ view: UIView, touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        previousTouchLocation = touch.location(in: view)
    }


    override func touchesMoved(_ view: UIView, touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: view)
        let delta = CGPoint(x: touchLocation.x - previousTouchLocation.x,
                            y: touchLocation.y - previousTouchLocation.y)

        let deltaX = Float(delta.x) * (GameConstants.gameWidth / Float(size.width))

        var newX = paddle.position.x + deltaX

        newX = min(max(newX, paddle.width / 2 ), GameConstants.gameWidth - paddle.width / 2)
        paddle.position.x = newX
        previousTouchLocation = touchLocation
    }

    func endGame(win: Bool) {
        let gameOverScene = GameOverScene(device: device, size: size)
        gameOverScene.win = win
        sceneDelegate?.transition(to: gameOverScene)
    }
}
