import SwiftUI

struct OrbData {
    var position: CGPoint
    var velocity: CGSize
    var size: CGFloat
    var opacity: Double
}

struct FloatingOrbsView: View {
    @State private var orbs: [OrbData] = []
    @State private var animationTimer: Timer?
    @State private var fingerPosition: CGPoint? = nil
    @State private var isFingerActive: Bool = false
    
    let orbCount: Int
    let baseSize: CGFloat
    let baseOpacity: Double
    let speed: Double
    
    init(orbCount: Int = 25, baseSize: CGFloat = 10, baseOpacity: Double = 0.8, speed: Double = 0.5) {
        self.orbCount = orbCount
        self.baseSize = baseSize
        self.baseOpacity = baseOpacity
        self.speed = speed
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(orbs.indices, id: \.self) { index in
                    if orbs.indices.contains(index) {
                        Circle()
                            .fill(Color.white.opacity(orbs[index].opacity))
                            .frame(width: orbs[index].size, height: orbs[index].size)
                            .position(orbs[index].position)
                            .animation(.easeOut(duration: 0.1), value: orbs[index].position)
                    }
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    fingerPosition = value.location
                    isFingerActive = true
                }
                .onEnded { _ in
                    isFingerActive = false
                    fingerPosition = nil
                }
        )
        .onAppear {
            setupOrbs()
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func setupOrbs() {
        orbs = (0..<orbCount).map { _ in
            OrbData(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                velocity: CGSize(
                    width: CGFloat.random(in: -speed...speed),
                    height: CGFloat.random(in: -speed...speed)
                ),
                size: CGFloat.random(in: baseSize*0.5...baseSize*1.5),
                opacity: Double.random(in: baseOpacity*0.6...baseOpacity*1.0)
            )
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateOrbPositions()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateOrbPositions() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for index in orbs.indices {
            // Check for finger collision if finger is active
            if isFingerActive, let fingerPos = fingerPosition {
                let distance = sqrt(pow(orbs[index].position.x - fingerPos.x, 2) + pow(orbs[index].position.y - fingerPos.y, 2))
                let collisionDistance: CGFloat = 40 // Collision radius around finger
                
                if distance < collisionDistance {
                    // Calculate bounce direction away from finger
                    let deltaX = orbs[index].position.x - fingerPos.x
                    let deltaY = orbs[index].position.y - fingerPos.y
                    let normalizedDistance = max(distance, 1) // Prevent division by zero
                    
                    // Apply bounce force
                    let bounceForce: CGFloat = 3.0
                    orbs[index].velocity.width = (deltaX / normalizedDistance) * bounceForce
                    orbs[index].velocity.height = (deltaY / normalizedDistance) * bounceForce
                    
                    // Add some sparkle effect on collision
                    orbs[index].opacity = min(1.0, orbs[index].opacity + 0.3)
                }
            }
            
            // Update position based on velocity
            orbs[index].position.x += orbs[index].velocity.width
            orbs[index].position.y += orbs[index].velocity.height
            
            // Add some random variation to movement (reduced when finger is active)
            let randomChance = isFingerActive ? 0.05 : 0.1
            if Double.random(in: 0...1) < randomChance {
                orbs[index].velocity.width += CGFloat.random(in: -0.2...0.2)
                orbs[index].velocity.height += CGFloat.random(in: -0.2...0.2)
                
                // Clamp velocity to prevent orbs from moving too fast
                orbs[index].velocity.width = max(-speed*3, min(speed*3, orbs[index].velocity.width))
                orbs[index].velocity.height = max(-speed*3, min(speed*3, orbs[index].velocity.height))
            }
            
            // Apply friction to gradually slow down dots
            orbs[index].velocity.width *= 0.98
            orbs[index].velocity.height *= 0.98
            
            // Ensure minimum movement when not bouncing
            if abs(orbs[index].velocity.width) < speed * 0.3 && abs(orbs[index].velocity.height) < speed * 0.3 && !isFingerActive {
                orbs[index].velocity.width += CGFloat.random(in: -speed*0.5...speed*0.5)
                orbs[index].velocity.height += CGFloat.random(in: -speed*0.5...speed*0.5)
            }
            
            // Bounce off edges or wrap around
            if orbs[index].position.x < -orbs[index].size {
                orbs[index].position.x = screenWidth + orbs[index].size
            } else if orbs[index].position.x > screenWidth + orbs[index].size {
                orbs[index].position.x = -orbs[index].size
            }
            
            if orbs[index].position.y < -orbs[index].size {
                orbs[index].position.y = screenHeight + orbs[index].size
            } else if orbs[index].position.y > screenHeight + orbs[index].size {
                orbs[index].position.y = -orbs[index].size
            }
            
            // Gradually return opacity to normal
            if orbs[index].opacity > baseOpacity * 1.0 {
                orbs[index].opacity = max(baseOpacity * 1.0, orbs[index].opacity - 0.02)
            }
            
            // Occasionally change opacity for subtle twinkling effect
            if Double.random(in: 0...1) < 0.02 { // 2% chance
                orbs[index].opacity = Double.random(in: baseOpacity*0.6...baseOpacity*1.0)
            }
        }
    }
}

struct FloatingOrbsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black // Dark background to see the white orbs
            FloatingOrbsView()
        }
        .ignoresSafeArea()
    }
}
