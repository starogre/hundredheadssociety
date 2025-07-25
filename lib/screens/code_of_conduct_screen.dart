import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CodeOfConductScreen extends StatelessWidget {
  const CodeOfConductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code of Conduct'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Code of Conduct',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last updated: July 2025',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'This event is a free event for artists to gain practice and experience painting from life. The organizers of the event have the right to ask anyone to leave who does not show respect to the model, artists or space.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Do not pester or harass the model or act in a way that is offensive or rude. They are sitting for free-you are welcome to pay someone on your own time to model.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'No pestering or acting in an inappropriate way to other artists. Do not offer un-solicited advice about another person\'s art.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is not a pick-up joint nor is it a place to air your political or religious beliefs. It\'s just not the time or place. Allow the space to be an art oasis.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'The next two points were borrowed from the fine folks at the Mobtown Ballroom and we whole heartedly agree: "This environment is for everyone regardless of gender/gender identity, race, sexual orientation, disability, physical appearance, religion, or whatever. We do not tolerate harassment of any kind. If you harass someone you may be asked to leave; you may be kicked out for life. It is at our discretion. So don\'t do it.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'In keeping with the above, don\'t use racist, misogynist, homophobic, transphobic, or ableist language. It\'s not only wrong, it\'s embarrassing and in bad taste. Anyone who uses language of this kind may be asked to leave, or banned."- the Mobtown Ballroom.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sometimes there is a large group of artists painting. Choose a spot as you arrive but if an organizer asks you to make space or move that is our right and what we see as best for the group. No one gets to "call a spot" in advance or force someone to move. You can politely ask another artist if they are willing to move or talk to an organizer if there is an issue.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'If an artist accidentally leaves something behind it is not yours. Do not use anyone else\'s materials without asking for permission.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Treat the studio with respect. Take all trash with you that you bring to the studio. We share it with other artists and it\'s not fair to leave it a mess. Wipe up any spills or paint that may have gotten on the floor or anywhere else in the room.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Do not leave food in the studio.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'If you feel uncomfortable with someones actions or words and don\'t feel comfortable addressing them, or an organizer was not around to witness the situation, please feel free to talk with one of the organizers if it can\'t be solved in person.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
} 